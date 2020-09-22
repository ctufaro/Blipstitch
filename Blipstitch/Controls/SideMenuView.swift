//
//  SideMenuView.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/18/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI

struct SideMenuView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct SideMenuView_Previews: PreviewProvider {
    @State static var show = true
    @State static var selectedIndex = ""
    static var previews: some View {
        SideMenu(show:$show,selectedIndex: $selectedIndex)
            .edgesIgnoringSafeArea(.all)
    }
}


struct SideMenu: View{
    @State var edges = UIApplication.shared.windows.first?.safeAreaInsets
    @State var width = UIScreen.main.bounds.width
    @State var min : CGFloat = 0
    @Binding var show : Bool
    @Binding var selectedIndex : String
    
    var body: some View{
        HStack(spacing:0){
            
            Spacer(minLength: 0)
            
            VStack{
                HStack{
                    Spacer(minLength: 0)
                    Button(action:{
                        withAnimation(.spring()){
                            self.show.toggle()
                        }
                    }, label:{
                        Image(systemName:"xmark")
                            .font(.system(size:22, weight:.bold))
                            .foregroundColor(.white)
                    })
                }
                .padding()
                .padding(.top,edges!.top)
                
                HStack(spacing: 15){

                    GeometryReader{reader in
                        Image("Chris")
                            .resizable()
                            .frame(width:75, height:75)
                            .clipShape(Circle())
                            .onAppear(perform:{
                                self.min = reader.frame(in: .global).minY
                        })
                    }
                    .frame(width:75, height:75)
                    
                    VStack(alignment: .leading, spacing: 5){
                        Text("Chris")
                            .font(.title)
                            .fontWeight(.semibold)
                        //Text("ctufaro@gmail.com")
                            //.fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal)
                
                // Menu Buttons
                VStack(alignment: .leading){
                    MenuButtons(image: "cart", title: "My Orders", selected: $selectedIndex, show: $show)
                    MenuButtons(image: "person", title: "My Profile", selected: $selectedIndex, show: $show)
                    MenuButtons(image: "mappin", title: "Delivery Address", selected: $selectedIndex, show: $show)
                    MenuButtons(image: "creditcard", title: "Payment Methods", selected: $selectedIndex, show: $show)
                    MenuButtons(image: "envelope", title: "Contact Us", selected: $selectedIndex, show: $show)
                    MenuButtons(image: "gear", title: "Settings", selected: $selectedIndex, show: $show)
                    MenuButtons(image: "info.circle", title: "Help & FAQs", selected: $selectedIndex, show: $show)
                }
                .padding(.top)
                .padding(.leading,45)
                
                Spacer(minLength: 0)
            }
            .frame(width: width - 100)
            .background(Color("Bg").clipShape(CustomShape(min: $min)))
            .offset(x: show ? 0 : width - 100)
        }
        .background(Color.black.opacity(show ? 0.3 : 0))
    }
}

struct MenuButtons: View{
    var image: String
    var title: String
    @Binding var selected : String
    @Binding var show : Bool
    
    var body: some View{
        Button(action: {
            
            withAnimation(.spring()){
                self.selected = self.title
                self.show.toggle()
            }
            
        }, label: {
            HStack(spacing: 15){
                Image(systemName: image)
                    .font(.system(size:22))
                    .frame(width:25, height:25)
                
                Text(title)
                    .font(.system(size:20))
                    .fontWeight(.semibold)
            }
            .padding(.vertical)
            .padding(.trailing)
        })
            .padding(.top,UIScreen.main.bounds.width < 750 ? -5 : 5)
            .foregroundColor(.white)
    }
}

struct CustomShape: Shape{
    @Binding var min : CGFloat
    
    func path(in rect: CGRect) -> Path{
        return Path{path in
            path.move(to: CGPoint(x: rect.width, y:0))
            path.addLine(to: CGPoint(x:rect.width, y:rect.height))
            path.addLine(to: CGPoint(x:35, y:rect.height))
            path.addLine(to: CGPoint(x:35, y:0))
            path.move(to: CGPoint(x:35, y:min-15))
            path.addQuadCurve(to: CGPoint(x:35, y: min+90), control: CGPoint(x:-35, y:min+35))
             
        }
    }
}
